import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves default alert profiles through their life cycle and keeps a journal of what it did.
    final class DefaultAlertProfileService {
        var store: any DefaultAlertProfileStore
        var validator: DefaultAlertProfileValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DefaultAlertProfileEngine

        init(store: any DefaultAlertProfileStore, validator: DefaultAlertProfileValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DefaultAlertProfileEngine) {
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
                throw Kit.Failure("default alert profile \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultAlertProfileStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default alert profile \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultAlertProfileStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("default alert profile \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newDefaultAlertProfileService(_ store: any DefaultAlertProfileStore, clock: any Kit.Clocks.Clock) -> DefaultAlertProfileService {
        return DefaultAlertProfileService(
            store: store,
            validator: defaultDefaultAlertProfileValidator(),
            clock: clock,
            journal: [],
            engine: defaultDefaultAlertProfileEngine()
        )
    }
}
