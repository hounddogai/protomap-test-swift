@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryManualConsentFormEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ManualConsentFormEstimateStore = Consent.newMemoryManualConsentFormEstimateStore()
        let item = Consent.newManualConsentFormEstimate("code-447", name: "name-731")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
