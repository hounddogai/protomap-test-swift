@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryRollingProxyOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.RollingProxyOverrideStore = Consent.newMemoryRollingProxyOverrideStore()
        let item = Consent.newRollingProxyOverride("code-137", name: "name-500")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
