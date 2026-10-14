@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentManualProxyScheduleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newManualProxySchedule("code-771", title: "title-115")
        let view = Consent.toManualProxyScheduleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toManualProxyScheduleViews([item, item]).count == 2)
    }
}
