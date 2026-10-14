import AcmePlatform
import Foundation

extension Consent {
    /// Moves witness tiers through their life cycle and keeps a journal of what it did.
    final class WitnessTierCoordinator {
        var store: any WitnessTierStore
        var validator: WitnessTierValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WitnessTierEngine

        init(store: any WitnessTierStore, validator: WitnessTierValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WitnessTierEngine) {
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
                throw Kit.Failure("witness tier \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WitnessTierStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("witness tier \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WitnessTierStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("witness tier \(code) not found")
            }
            let result = engine.run(item)
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

    static func newWitnessTierCoordinator(_ store: any WitnessTierStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> WitnessTierCoordinator {
        return WitnessTierCoordinator(
            store: store,
            validator: defaultWitnessTierValidator(),
            clock: clock,
            journal: [],
            engine: defaultWitnessTierEngine(flags)
        )
    }
}
