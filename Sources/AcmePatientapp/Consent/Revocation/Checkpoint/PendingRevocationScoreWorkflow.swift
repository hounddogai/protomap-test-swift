import AcmePlatform
import Foundation

extension Consent {
    /// Moves pending revocation scores through their life cycle and keeps a journal of what it did.
    final class PendingRevocationScoreCoordinator {
        var store: any PendingRevocationScoreStore
        var validator: PendingRevocationScoreValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PendingRevocationScoreEngine

        init(store: any PendingRevocationScoreStore, validator: PendingRevocationScoreValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PendingRevocationScoreEngine) {
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
                throw Kit.Failure("pending revocation score \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingRevocationScoreStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending revocation score \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingRevocationScoreStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending revocation score \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newPendingRevocationScoreCoordinator(_ store: any PendingRevocationScoreStore, clock: any Kit.Clocks.Clock) -> PendingRevocationScoreCoordinator {
        return PendingRevocationScoreCoordinator(
            store: store,
            validator: defaultPendingRevocationScoreValidator(),
            clock: clock,
            journal: [],
            engine: defaultPendingRevocationScoreEngine()
        )
    }
}
