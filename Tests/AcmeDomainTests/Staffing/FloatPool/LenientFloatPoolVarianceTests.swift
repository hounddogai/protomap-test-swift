@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLenientFloatPoolVarianceTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newLenientFloatPoolVariance("code-536", title: "title-404")
        #expect(item.status == Staffing.LenientFloatPoolVarianceStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Staffing.newLenientFloatPoolVariance("code-536", title: "title-404")
        try item.moveTo(Staffing.LenientFloatPoolVarianceStatus.draining)
        #expect(item.status == Staffing.LenientFloatPoolVarianceStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newLenientFloatPoolVariance("code-536", title: "title-404")
        item.status = Staffing.LenientFloatPoolVarianceStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.LenientFloatPoolVarianceStatus.idle) }
    }
}
