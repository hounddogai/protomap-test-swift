@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementStrictCensusTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newStrictCensusTemplate("code-139", title: "title-951")
        let view = BedManagement.toStrictCensusTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toStrictCensusTemplateViews([item, item]).count == 2)
    }
}
