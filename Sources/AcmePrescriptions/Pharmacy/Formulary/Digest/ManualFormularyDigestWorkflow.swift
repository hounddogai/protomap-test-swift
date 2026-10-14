import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves manual formulary digests through their life cycle and keeps a journal of what it did.
    final class ManualFormularyDigestManager {
        var store: any ManualFormularyDigestStore
        var validator: ManualFormularyDigestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ManualFormularyDigestEngine

        init(store: any ManualFormularyDigestStore, validator: ManualFormularyDigestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ManualFormularyDigestEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual formulary digest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualFormularyDigestStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual formulary digest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualFormularyDigestStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual formulary digest \(code) not found")
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

    static func newManualFormularyDigestManager(_ store: any ManualFormularyDigestStore, clock: any Kit.Clocks.Clock) -> ManualFormularyDigestManager {
        return ManualFormularyDigestManager(
            store: store,
            validator: defaultManualFormularyDigestValidator(),
            clock: clock,
            journal: [],
            engine: defaultManualFormularyDigestEngine()
        )
    }
}
