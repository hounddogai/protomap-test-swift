@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryPrimaryReadAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.PrimaryReadAgreementStore = Imaging.newMemoryPrimaryReadAgreementStore()
        let item = Imaging.newPrimaryReadAgreement("code-762", name: "name-633")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
