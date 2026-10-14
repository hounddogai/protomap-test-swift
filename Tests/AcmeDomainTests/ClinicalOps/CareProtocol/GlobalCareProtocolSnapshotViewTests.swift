@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalCareProtocolSnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newGlobalCareProtocolSnapshot("code-301", name: "name-632")
        let view = ClinicalOps.toGlobalCareProtocolSnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toGlobalCareProtocolSnapshotViews([item, item]).count == 2)
    }
}
