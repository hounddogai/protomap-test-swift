import AcmePlatform
import Foundation
import Testing

@Suite struct KitNumbersTests {
    @Test func clampsIntoRange() throws {
        #expect(Kit.Numbers.clamp(12, low: 0, high: 10) == 10)
        #expect(Kit.Numbers.clamp(-3, low: 0, high: 10) == 0)
        #expect(Kit.Numbers.percent(1.0, whole: 4.0) == 25.0)
    }

    @Test func findsTheMedianByRank() throws {
        #expect(Kit.Numbers.percentile([5.0, 1.0, 3.0], p: 50.0) == 3.0)
        #expect(Kit.Numbers.mean([]) == 0.0)
        #expect(throws: (any Error).self) { try Kit.Numbers.weightedMean([1.0], weights: []) }
    }
}
