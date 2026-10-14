@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newHandoffCheckpoint("code-710", title: "title-681")
        let view = ClinicalOps.toHandoffCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toHandoffCheckpointViews([item, item]).count == 2)
    }
}
