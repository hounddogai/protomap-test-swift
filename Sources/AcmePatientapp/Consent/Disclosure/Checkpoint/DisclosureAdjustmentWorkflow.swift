import AcmePlatform
import Foundation

extension Consent {
    /// Moves disclosure adjustments through their life cycle and keeps a journal of what it did.
    final class DisclosureAdjustmentWorkflow {
        var store: any DisclosureAdjustmentStore
        var validator: DisclosureAdjustmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any DisclosureAdjustmentStore, validator: DisclosureAdjustmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("disclosure adjustment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DisclosureAdjustmentStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("disclosure adjustment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DisclosureAdjustmentStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newDisclosureAdjustmentWorkflow(_ store: any DisclosureAdjustmentStore, clock: any Kit.Clocks.Clock) -> DisclosureAdjustmentWorkflow {
        return DisclosureAdjustmentWorkflow(
            store: store,
            validator: defaultDisclosureAdjustmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
