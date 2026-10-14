import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves capped statement exceptions through their life cycle and keeps a journal of what it did.
    final class CappedStatementExceptionDesk {
        var store: any CappedStatementExceptionStore
        var validator: CappedStatementExceptionValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CappedStatementExceptionEngine

        init(store: any CappedStatementExceptionStore, validator: CappedStatementExceptionValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CappedStatementExceptionEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped statement exception \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedStatementExceptionStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped statement exception \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedStatementExceptionStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped statement exception \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newCappedStatementExceptionDesk(_ store: any CappedStatementExceptionStore, clock: any Kit.Clocks.Clock) -> CappedStatementExceptionDesk {
        return CappedStatementExceptionDesk(
            store: store,
            validator: defaultCappedStatementExceptionValidator(),
            clock: clock,
            journal: [],
            engine: defaultCappedStatementExceptionEngine()
        )
    }
}
