@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newProgramManifest("code-640", name: "name-615")
        let view = CareManagement.toProgramManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toProgramManifestViews([item, item]).count == 2)
    }
}
