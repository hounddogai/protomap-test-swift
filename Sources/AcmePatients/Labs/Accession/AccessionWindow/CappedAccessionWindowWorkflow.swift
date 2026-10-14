import AcmePlatform
import Foundation

extension Labs {
    /// Moves capped accession windows through their life cycle and keeps a journal of what it did.
    final class CappedAccessionWindowCoordinator {
        var store: any CappedAccessionWindowStore
        var validator: CappedAccessionWindowValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CappedAccessionWindowEngine

        init(store: any CappedAccessionWindowStore, validator: CappedAccessionWindowValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CappedAccessionWindowEngine) {
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
                throw Kit.Failure("capped accession window \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedAccessionWindowStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped accession window \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedAccessionWindowStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped accession window \(code) not found")
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
                if item.endsAt > cutoff {
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

    static func newCappedAccessionWindowCoordinator(_ store: any CappedAccessionWindowStore, clock: any Kit.Clocks.Clock) -> CappedAccessionWindowCoordinator {
        return CappedAccessionWindowCoordinator(
            store: store,
            validator: defaultCappedAccessionWindowValidator(),
            clock: clock,
            journal: [],
            engine: defaultCappedAccessionWindowEngine()
        )
    }
}
