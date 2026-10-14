@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryProxyReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ProxyReservationStore = Consent.newMemoryProxyReservationStore()
        let item = Consent.newProxyReservation("code-761", name: "name-273")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
