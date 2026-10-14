@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newOutreachTemplate("code-824", title: "title-644")
        let view = CareManagement.toOutreachTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toOutreachTemplateViews([item, item]).count == 2)
    }
}
