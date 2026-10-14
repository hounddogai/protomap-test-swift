@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryWitnessVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.WitnessVarianceStore = Consent.newMemoryWitnessVarianceStore()
        let item = Consent.newWitnessVariance("code-45", label: "label-757")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
