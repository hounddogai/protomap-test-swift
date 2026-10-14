@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryGlobalPriorityAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.GlobalPriorityAgreementStore = Imaging.newMemoryGlobalPriorityAgreementStore()
        let item = Imaging.newGlobalPriorityAgreement("code-89", name: "name-635")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
