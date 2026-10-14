import AcmePlatform
import Foundation

extension Imaging {
    /// Moves worklist scores through their life cycle and keeps a journal of what it did.
    final class WorklistScoreDesk {
        var store: any WorklistScoreStore
        var validator: WorklistScoreValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WorklistScoreEngine

        init(store: any WorklistScoreStore, validator: WorklistScoreValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WorklistScoreEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("worklist score \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WorklistScoreStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("worklist score \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WorklistScoreStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("worklist score \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newWorklistScoreDesk(_ store: any WorklistScoreStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> WorklistScoreDesk {
        return WorklistScoreDesk(
            store: store,
            validator: defaultWorklistScoreValidator(),
            clock: clock,
            journal: [],
            engine: defaultWorklistScoreEngine(flags)
        )
    }
}
