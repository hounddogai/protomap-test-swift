@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryReadAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ReadAgreementStore = Imaging.newMemoryReadAgreementStore()
        let item = Imaging.newReadAgreement("code-545", title: "title-983")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
