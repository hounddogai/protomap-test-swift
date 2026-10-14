@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemorySubstitutionNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.SubstitutionNoticeStore = Pharmacy.newMemorySubstitutionNoticeStore()
        let item = Pharmacy.newSubstitutionNotice("code-10", title: "title-183")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
