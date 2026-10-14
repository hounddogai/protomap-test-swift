import AcmePlatform
import Foundation

extension Imaging {
    /// Moves care protocol groups through their life cycle and keeps a journal of what it did.
    final class CareProtocolGroupWorkflow {
        var store: any CareProtocolGroupStore
        var validator: CareProtocolGroupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CareProtocolGroupEngine

        init(store: any CareProtocolGroupStore, validator: CareProtocolGroupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CareProtocolGroupEngine) {
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
                throw Kit.Failure("care protocol group \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CareProtocolGroupStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care protocol group \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CareProtocolGroupStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("care protocol group \(code) not found")
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
                if item.createdAt > cutoff {
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

    static func newCareProtocolGroupWorkflow(_ store: any CareProtocolGroupStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CareProtocolGroupWorkflow {
        return CareProtocolGroupWorkflow(
            store: store,
            validator: defaultCareProtocolGroupValidator(),
            clock: clock,
            journal: [],
            engine: defaultCareProtocolGroupEngine(flags)
        )
    }
}
