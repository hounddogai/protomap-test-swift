@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newFloatPoolDraft("code-759", name: "name-584")
        let view = Staffing.toFloatPoolDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toFloatPoolDraftViews([item, item]).count == 2)
    }
}
