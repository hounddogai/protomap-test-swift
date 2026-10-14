import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves global isolation windows through their life cycle and keeps a journal of what it did.
    final class GlobalIsolationWindowService {
        var store: any GlobalIsolationWindowStore
        var validator: GlobalIsolationWindowValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GlobalIsolationWindowEngine

        init(store: any GlobalIsolationWindowStore, validator: GlobalIsolationWindowValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GlobalIsolationWindowEngine) {
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
                throw Kit.Failure("global isolation window \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalIsolationWindowStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global isolation window \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalIsolationWindowStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("global isolation window \(code) not found")
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

    static func newGlobalIsolationWindowService(_ store: any GlobalIsolationWindowStore, clock: any Kit.Clocks.Clock) -> GlobalIsolationWindowService {
        return GlobalIsolationWindowService(
            store: store,
            validator: defaultGlobalIsolationWindowValidator(),
            clock: clock,
            journal: [],
            engine: defaultGlobalIsolationWindowEngine()
        )
    }
}
