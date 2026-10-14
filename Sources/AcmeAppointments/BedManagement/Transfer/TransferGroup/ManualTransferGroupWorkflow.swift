import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves manual transfer groups through their life cycle and keeps a journal of what it did.
    final class ManualTransferGroupManager {
        var store: any ManualTransferGroupStore
        var validator: ManualTransferGroupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ManualTransferGroupEngine

        init(store: any ManualTransferGroupStore, validator: ManualTransferGroupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ManualTransferGroupEngine) {
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
                throw Kit.Failure("manual transfer group \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualTransferGroupStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual transfer group \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualTransferGroupStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual transfer group \(code) not found")
            }
            let result = engine.run(item)
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

    static func newManualTransferGroupManager(_ store: any ManualTransferGroupStore, clock: any Kit.Clocks.Clock) -> ManualTransferGroupManager {
        return ManualTransferGroupManager(
            store: store,
            validator: defaultManualTransferGroupValidator(),
            clock: clock,
            journal: [],
            engine: defaultManualTransferGroupEngine()
        )
    }
}
