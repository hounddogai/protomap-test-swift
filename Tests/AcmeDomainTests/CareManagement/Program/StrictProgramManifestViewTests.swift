@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementStrictProgramManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newStrictProgramManifest("code-340", label: "label-543")
        let view = CareManagement.toStrictProgramManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toStrictProgramManifestViews([item, item]).count == 2)
    }
}
