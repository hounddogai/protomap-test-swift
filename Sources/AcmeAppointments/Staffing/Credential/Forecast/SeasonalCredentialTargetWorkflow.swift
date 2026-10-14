import AcmePlatform
import Foundation

extension Staffing {
    /// Moves seasonal credential targets through their life cycle and keeps a journal of what it did.
    final class SeasonalCredentialTargetManager {
        var store: any SeasonalCredentialTargetStore
        var validator: SeasonalCredentialTargetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SeasonalCredentialTargetEngine

        init(store: any SeasonalCredentialTargetStore, validator: SeasonalCredentialTargetValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SeasonalCredentialTargetEngine) {
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
                throw Kit.Failure("seasonal credential target \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalCredentialTargetStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal credential target \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalCredentialTargetStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal credential target \(code) not found")
            }
            let result = engine.price(item)
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

    static func newSeasonalCredentialTargetManager(_ store: any SeasonalCredentialTargetStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> SeasonalCredentialTargetManager {
        return SeasonalCredentialTargetManager(
            store: store,
            validator: defaultSeasonalCredentialTargetValidator(),
            clock: clock,
            journal: [],
            engine: defaultSeasonalCredentialTargetEngine(flags)
        )
    }
}
