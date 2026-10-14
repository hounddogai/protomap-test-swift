@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryRollingProxyWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.RollingProxyWindowStore = Consent.newMemoryRollingProxyWindowStore()
        let item = Consent.newRollingProxyWindow("code-781", name: "name-112")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
