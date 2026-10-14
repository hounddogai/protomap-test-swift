@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryWitnessSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.WitnessSegmentStore = Consent.newMemoryWitnessSegmentStore()
        let item = Consent.newWitnessSegment("code-370", label: "label-289")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
