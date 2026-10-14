import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves manual recall scores through their life cycle and keeps a journal of what it did.
    final class ManualRecallScoreWorkflow {
        var store: any ManualRecallScoreStore
        var validator: ManualRecallScoreValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ManualRecallScoreStore, validator: ManualRecallScoreValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("manual recall score \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualRecallScoreStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual recall score \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualRecallScoreStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newManualRecallScoreWorkflow(_ store: any ManualRecallScoreStore, clock: any Kit.Clocks.Clock) -> ManualRecallScoreWorkflow {
        return ManualRecallScoreWorkflow(
            store: store,
            validator: defaultManualRecallScoreValidator(),
            clock: clock,
            journal: []
        )
    }
}
