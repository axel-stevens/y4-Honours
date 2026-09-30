// Tiny header-only test framework. Avoids pulling in GoogleTest for ~30 tests.
#pragma once

#include <cstdio>
#include <cstdlib>
#include <functional>
#include <sstream>
#include <string>
#include <vector>

namespace pupradar::test {

struct TestCase {
    std::string           name;
    std::function<void()> fn;
};

inline std::vector<TestCase>& registry() {
    static std::vector<TestCase> r;
    return r;
}

struct Registrar {
    Registrar(const char* name, std::function<void()> fn) {
        registry().push_back({name, std::move(fn)});
    }
};

class AssertionError : public std::runtime_error {
public:
    using std::runtime_error::runtime_error;
};

inline int runAll() {
    int failed = 0;
    for (const auto& tc : registry()) {
        std::printf("[ RUN      ] %s\n", tc.name.c_str());
        try {
            tc.fn();
            std::printf("[       OK ] %s\n", tc.name.c_str());
        } catch (const AssertionError& e) {
            std::printf("[  FAILED  ] %s\n  %s\n", tc.name.c_str(), e.what());
            ++failed;
        } catch (const std::exception& e) {
            std::printf("[  FAILED  ] %s\n  unexpected exception: %s\n",
                        tc.name.c_str(), e.what());
            ++failed;
        }
    }
    std::printf("\n%zu tests, %d failed.\n", registry().size(), failed);
    return failed == 0 ? 0 : 1;
}

}  // namespace pupradar::test

#define PUPRADAR_TEST(name) \
    static void test_##name(); \
    static ::pupradar::test::Registrar reg_##name(#name, test_##name); \
    static void test_##name()

#define ASSERT_TRUE(expr) \
    do { if (!(expr)) { \
        std::ostringstream _o; \
        _o << __FILE__ << ":" << __LINE__ << " ASSERT_TRUE(" #expr ") failed"; \
        throw ::pupradar::test::AssertionError(_o.str()); \
    } } while (0)

#define ASSERT_FALSE(expr) ASSERT_TRUE(!(expr))

#define ASSERT_EQ(a, b) \
    do { auto _av = (a); auto _bv = (b); \
        if (!(_av == _bv)) { \
            std::ostringstream _o; \
            _o << __FILE__ << ":" << __LINE__ << " ASSERT_EQ failed: " \
               << (_av) << " != " << (_bv); \
            throw ::pupradar::test::AssertionError(_o.str()); \
        } } while (0)

#define ASSERT_NE(a, b) \
    do { auto _av = (a); auto _bv = (b); \
        if (_av == _bv) { \
            std::ostringstream _o; \
            _o << __FILE__ << ":" << __LINE__ << " ASSERT_NE failed: " \
               << (_av) << " == " << (_bv); \
            throw ::pupradar::test::AssertionError(_o.str()); \
        } } while (0)

#define ASSERT_THROWS(stmt, ExceptionT) \
    do { \
        bool _threw = false; \
        try { stmt; } catch (const ExceptionT&) { _threw = true; } \
        catch (...) { \
            throw ::pupradar::test::AssertionError( \
                std::string(__FILE__ ":") + std::to_string(__LINE__) + \
                " ASSERT_THROWS: wrong exception type"); \
        } \
        if (!_threw) { \
            throw ::pupradar::test::AssertionError( \
                std::string(__FILE__ ":") + std::to_string(__LINE__) + \
                " ASSERT_THROWS: did not throw"); \
        } \
    } while (0)
