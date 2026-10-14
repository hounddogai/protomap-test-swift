@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryScheduledDisclosureReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ScheduledDisclosureReservationStore = Consent.newMemoryScheduledDisclosureReservationStore()
        let item = Consent.newScheduledDisclosureReservation("code-834", label: "label-760")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
