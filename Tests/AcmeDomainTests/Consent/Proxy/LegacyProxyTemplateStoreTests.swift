@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryLegacyProxyTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.LegacyProxyTemplateStore = Consent.newMemoryLegacyProxyTemplateStore()
        let item = Consent.newLegacyProxyTemplate("code-456", title: "title-844")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
