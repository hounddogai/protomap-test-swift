@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultSubstitutionExceptionReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702418143)
        var items: [Pharmacy.DefaultSubstitutionException] = []
        for index in 0..<2 {
            items.append(Pharmacy.newDefaultSubstitutionException("default-substitution-exception-\(index)", label: "sample"))
        }
        let report = Pharmacy.buildDefaultSubstitutionExceptionReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
