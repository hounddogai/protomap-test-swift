@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementDefaultGoalManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newDefaultGoalManifest("code-40", label: "label-166")
        let view = CareManagement.toDefaultGoalManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toDefaultGoalManifestViews([item, item]).count == 2)
    }
}
