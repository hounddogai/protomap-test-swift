@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryPrimarySubstitutionNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.PrimarySubstitutionNoticeStore = Pharmacy.newMemoryPrimarySubstitutionNoticeStore()
        let item = Pharmacy.newPrimarySubstitutionNotice("code-769", label: "label-42")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
