import React from 'react'
import { motion } from "framer-motion";
import { Hook } from '../hook/Hook';
import { MainContext, useContext } from '../Context';

const StatusTable = ['Health','Armour','Hunger','Thirst','Stamina','Stress']

export default function Status() {
  const { Status, UIColor } = useContext(MainContext);
  return (
    <div className='Status'>
      {StatusTable.map((index) => {
        const percent = Math.max(0, Math.min(100, Math.round(Number(Status[index]) || 0)))

        return (
        <motion.div key={index} className="Stat" animate={{animation: ((Status[index] < 17 && index !== 'Armour' && Status[index] < 17 && index !== 'Stress')) && 'Flash .7s infinite alternate'}} >
          <div className="Icon" style={{filter:`drop-shadow(0 0 .25rem ${UIColor.is[index]}40)`}}>{Hook.GetSVG(`Icon${index}`, UIColor.is[index])}</div>
          {Hook.GetSVG('StatusSVG', UIColor.is[index], percent)}
          <span className="Percent" style={{color: UIColor.is[index]}}>{percent}%</span>
        </motion.div>
        )
      })}
    </div>
  )
}
