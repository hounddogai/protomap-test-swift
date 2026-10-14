import AcmePlatform
import Foundation

extension Labs {
    /// Moves accession mappings through their life cycle and keeps a journal of what it did.
    final class AccessionMappingWorkflow {
        var store: any AccessionMappingStore
        var validator: AccessionMappingValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any AccessionMappingStore, validator: AccessionMappingValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("accession mapping \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AccessionMappingStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("accession mapping \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AccessionMappingStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newAccessionMappingWorkflow(_ store: any AccessionMappingStore, clock: any Kit.Clocks.Clock) -> AccessionMappingWorkflow {
        return AccessionMappingWorkflow(
            store: store,
            validator: defaultAccessionMappingValidator(),
            clock: clock,
            journal: []
        )
    }
}
