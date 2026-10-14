@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialForecastViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newCredentialForecast("code-173", title: "title-67")
        let view = Staffing.toCredentialForecastView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toCredentialForecastViews([item, item]).count == 2)
    }
}
