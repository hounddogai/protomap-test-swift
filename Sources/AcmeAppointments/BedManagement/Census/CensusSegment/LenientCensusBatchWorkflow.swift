import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves lenient census batches through their life cycle and keeps a journal of what it did.
    final class LenientCensusBatchWorkflow {
        var store: any LenientCensusBatchStore
        var validator: LenientCensusBatchValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any LenientCensusBatchStore, validator: LenientCensusBatchValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient census batch \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientCensusBatchStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient census batch \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientCensusBatchStatus.closed)
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

    static func newLenientCensusBatchWorkflow(_ store: any LenientCensusBatchStore, clock: any Kit.Clocks.Clock) -> LenientCensusBatchWorkflow {
        return LenientCensusBatchWorkflow(
            store: store,
            validator: defaultLenientCensusBatchValidator(),
            clock: clock,
            journal: []
        )
    }
}
