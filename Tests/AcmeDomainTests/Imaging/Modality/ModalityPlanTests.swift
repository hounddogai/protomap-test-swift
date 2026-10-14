@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityPlanTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newModalityPlan("code-872", title: "title-261")
        #expect(item.status == Imaging.ModalityPlanStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Imaging.newModalityPlan("code-872", title: "title-261")
        try item.moveTo(Imaging.ModalityPlanStatus.warming)
        #expect(item.status == Imaging.ModalityPlanStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newModalityPlan("code-872", title: "title-261")
        item.status = Imaging.ModalityPlanStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ModalityPlanStatus.idle) }
    }
}
