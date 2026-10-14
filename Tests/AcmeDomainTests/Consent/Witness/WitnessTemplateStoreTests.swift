@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryWitnessTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.WitnessTemplateStore = Consent.newMemoryWitnessTemplateStore()
        let item = Consent.newWitnessTemplate("code-190", title: "title-954")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
