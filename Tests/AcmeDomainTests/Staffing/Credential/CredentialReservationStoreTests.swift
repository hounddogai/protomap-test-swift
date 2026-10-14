@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryCredentialReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.CredentialReservationStore = Staffing.newMemoryCredentialReservationStore()
        let item = Staffing.newCredentialReservation("code-617", title: "title-500")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
