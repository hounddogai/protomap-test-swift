@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newCareGapManifest("code-201", title: "title-287")
        let view = CareManagement.toCareGapManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toCareGapManifestViews([item, item]).count == 2)
    }
}
