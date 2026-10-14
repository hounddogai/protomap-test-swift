@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryWitnessAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.WitnessAssignmentStore = Consent.newMemoryWitnessAssignmentStore()
        let item = Consent.newWitnessAssignment("code-870", title: "title-484")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
