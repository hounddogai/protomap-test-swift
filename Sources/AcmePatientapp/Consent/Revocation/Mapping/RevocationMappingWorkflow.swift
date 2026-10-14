import AcmePlatform
import Foundation

extension Consent {
    /// Moves revocation mappings through their life cycle and keeps a journal of what it did.
    final class RevocationMappingDesk {
        var store: any RevocationMappingStore
        var validator: RevocationMappingValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RevocationMappingStore, validator: RevocationMappingValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("revocation mapping \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RevocationMappingStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("revocation mapping \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RevocationMappingStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
                    continue
                }
                let problems = validator.validate(item)
                if problems.count == 0 {
                    continue
                }
                self.note("\(item.code) needs attention: \(problems.joined(separator: ", "))")
                changed += 1
            }
            return changed
        }
    }

    static func newRevocationMappingDesk(_ store: any RevocationMappingStore, clock: any Kit.Clocks.Clock) -> RevocationMappingDesk {
        return RevocationMappingDesk(
            store: store,
            validator: defaultRevocationMappingValidator(),
            clock: clock,
            journal: []
        )
    }
}
