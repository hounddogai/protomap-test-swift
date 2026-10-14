import AcmePlatform
import Foundation

extension Labs {
    /// Moves specimen targets through their life cycle and keeps a journal of what it did.
    final class SpecimenTargetService {
        var store: any SpecimenTargetStore
        var validator: SpecimenTargetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SpecimenTargetEngine

        init(store: any SpecimenTargetStore, validator: SpecimenTargetValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SpecimenTargetEngine) {
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
                throw Kit.Failure("specimen target \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SpecimenTargetStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("specimen target \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SpecimenTargetStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("specimen target \(code) not found")
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

    static func newSpecimenTargetService(_ store: any SpecimenTargetStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> SpecimenTargetService {
        return SpecimenTargetService(
            store: store,
            validator: defaultSpecimenTargetValidator(),
            clock: clock,
            journal: [],
            engine: defaultSpecimenTargetEngine(flags)
        )
    }
}
