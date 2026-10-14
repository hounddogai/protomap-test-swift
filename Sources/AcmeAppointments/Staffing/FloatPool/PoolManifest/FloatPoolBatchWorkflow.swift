import AcmePlatform
import Foundation

extension Staffing {
    /// Moves float pool batches through their life cycle and keeps a journal of what it did.
    final class FloatPoolBatchManager {
        var store: any FloatPoolBatchStore
        var validator: FloatPoolBatchValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any FloatPoolBatchStore, validator: FloatPoolBatchValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("float pool batch \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FloatPoolBatchStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("float pool batch \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FloatPoolBatchStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
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

    static func newFloatPoolBatchManager(_ store: any FloatPoolBatchStore, clock: any Kit.Clocks.Clock) -> FloatPoolBatchManager {
        return FloatPoolBatchManager(
            store: store,
            validator: defaultFloatPoolBatchValidator(),
            clock: clock,
            journal: []
        )
    }
}
