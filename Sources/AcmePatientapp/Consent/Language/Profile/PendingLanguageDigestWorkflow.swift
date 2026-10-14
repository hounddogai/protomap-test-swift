import AcmePlatform
import Foundation

extension Consent {
    /// Moves pending language digests through their life cycle and keeps a journal of what it did.
    final class PendingLanguageDigestCoordinator {
        var store: any PendingLanguageDigestStore
        var validator: PendingLanguageDigestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PendingLanguageDigestEngine

        init(store: any PendingLanguageDigestStore, validator: PendingLanguageDigestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PendingLanguageDigestEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending language digest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingLanguageDigestStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending language digest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingLanguageDigestStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending language digest \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newPendingLanguageDigestCoordinator(_ store: any PendingLanguageDigestStore, clock: any Kit.Clocks.Clock) -> PendingLanguageDigestCoordinator {
        return PendingLanguageDigestCoordinator(
            store: store,
            validator: defaultPendingLanguageDigestValidator(),
            clock: clock,
            journal: [],
            engine: defaultPendingLanguageDigestEngine()
        )
    }
}
