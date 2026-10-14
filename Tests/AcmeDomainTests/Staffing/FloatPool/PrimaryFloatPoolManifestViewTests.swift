@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryFloatPoolManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newPrimaryFloatPoolManifest("code-425", label: "label-401")
        let view = Staffing.toPrimaryFloatPoolManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toPrimaryFloatPoolManifestViews([item, item]).count == 2)
    }
}
