import AcmePlatform
import Foundation

extension Consent {
    /// Moves disclosure mappings through their life cycle and keeps a journal of what it did.
    final class DisclosureMappingWorkflow {
        var store: any DisclosureMappingStore
        var validator: DisclosureMappingValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any DisclosureMappingStore, validator: DisclosureMappingValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("disclosure mapping \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DisclosureMappingStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("disclosure mapping \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DisclosureMappingStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
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

    static func newDisclosureMappingWorkflow(_ store: any DisclosureMappingStore, clock: any Kit.Clocks.Clock) -> DisclosureMappingWorkflow {
        return DisclosureMappingWorkflow(
            store: store,
            validator: defaultDisclosureMappingValidator(),
            clock: clock,
            journal: []
        )
    }
}
