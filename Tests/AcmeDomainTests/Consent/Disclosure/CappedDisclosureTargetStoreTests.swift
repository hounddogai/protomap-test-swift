@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryCappedDisclosureTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.CappedDisclosureTargetStore = Consent.newMemoryCappedDisclosureTargetStore()
        let item = Consent.newCappedDisclosureTarget("code-900", title: "title-109")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
